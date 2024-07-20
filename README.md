# dlang-dockerized/images

Container images with compilers and tools for the D Programming Language.

## Further information

See <https://github.com/dlang-dockerized/containerfiles> for containerfiles
and <https://github.com/dlang-dockerized/packaging> for templates and source
code.

Please visit <https://github.com/dlang-dockerized/packaging/issues> to report
issues specific to the “dockerized” distribution.

Bug reports for the packaged compilers and tools should be submitted to the
upstream issue trackers.

Keep in mind that we also package outdated versions that are no longer
supported by upstream and will not receive any bugfixes. Check out the release
schedules and update policies of those upstream projects for further
information. Upstream projects often support only their latest release.

## Downstream policy

The dlang-dockerized project itends to packages applications as released by
their respective maintainers, thus we do not backport bugfixes.
We explicitly reserve the option to include and apply compatibility patches.

The containerfiles and container images published by this project are provided
for testing and educational purposes.

Older upstream-versions of the packaged programs, usually indicated by lower
version numbers, may be subject to known issues and security vulnerabilities.
Do not use such versions for non-experimental purposes.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT
SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE
FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
