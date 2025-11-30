using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Karta.Model.Migrations
{
    /// <inheritdoc />
    public partial class AddIsOrganizerVerifiedToUsers : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "IsOrganizerVerified",
                table: "AspNetUsers",
                type: "INTEGER",
                nullable: false,
                defaultValue: false);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "IsOrganizerVerified",
                table: "AspNetUsers");
        }
    }
}
