# Copyright 2016 Google Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "helper"

describe Google::Cloud::Spanner::Project, :session, :mock_spanner do
  let(:instance_id) { "my-instance-id" }
  let(:database_id) { "my-database-id" }
  let(:session_id) { "session123" }
  let(:session_grpc) { Google::Spanner::V1::Session.new name: session_path(instance_id, database_id, session_id) }
  let(:session) { Google::Cloud::Spanner::Session.from_grpc session_grpc, spanner.service }

  it "creates a session when called with no session_id" do
    mock = Minitest::Mock.new
    mock.expect :create_session, session_grpc, [database_path(instance_id, database_id)]
    spanner.service.mocked_service = mock

    session = spanner.session instance_id, database_id

    mock.verify

    session.must_be_kind_of Google::Cloud::Spanner::Session
    session.project_id.must_equal project
    session.instance_id.must_equal instance_id
    session.database_id.must_equal database_id
    session.session_id.must_equal session_id
    session.path.must_equal session_path(instance_id, database_id, session_id)
  end

  it "retrieves a session when called with a session_id" do
    mock = Minitest::Mock.new
    mock.expect :get_session, session_grpc, [session_path(instance_id, database_id, session_id)]
    spanner.service.mocked_service = mock

    session = spanner.session instance_id, database_id, session_id

    mock.verify

    session.must_be_kind_of Google::Cloud::Spanner::Session
    session.project_id.must_equal project
    session.instance_id.must_equal instance_id
    session.database_id.must_equal database_id
    session.session_id.must_equal session_id
    session.path.must_equal session_path(instance_id, database_id, session_id)
  end

  it "raises an error when retriving a session that does not exist" do
    not_found_session_id = "not-found-session"

    stub = Object.new
    def stub.get_session *args
      gax_error = Google::Gax::GaxError.new "not found"
      gax_error.instance_variable_set :@cause, GRPC::BadStatus.new(5, "not found")
      raise gax_error
    end
    spanner.service.mocked_service = stub

    expect do
      spanner.session instance_id, database_id, not_found_session_id
    end.must_raise Google::Cloud::NotFoundError
  end
end
