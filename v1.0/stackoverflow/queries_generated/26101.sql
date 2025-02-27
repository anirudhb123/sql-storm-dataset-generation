WITH TagCounts AS (
    SELECT
        tag.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM
        Tags tag
    JOIN
        Posts p ON tag.Id = ANY (string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')::int[])
    GROUP BY
        tag.TagName
),
UserActivity AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COUNT(DISTINCT b.Id) AS TotalBadges,
        COUNT(DISTINCT h.Id) AS TotalPostEdits
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN
        Comments c ON u.Id = c.UserId
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    LEFT JOIN
        PostHistory h ON u.Id = h.UserId
    LEFT JOIN
        Votes v ON v.UserId = u.Id
    GROUP BY
        u.Id, u.DisplayName
),
MostActiveUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.TotalPosts,
        ua.TotalComments,
        ua.TotalBadges,
        ua.TotalPostEdits,
        ROW_NUMBER() OVER (ORDER BY ua.TotalPosts DESC, ua.TotalComments DESC) AS ActivityRank
    FROM
        UserActivity ua
)
SELECT
    tc.TagName,
    tc.PostCount,
    tc.QuestionCount,
    tc.AnswerCount,
    mau.UserId,
    mau.DisplayName AS ActiveUser,
    mau.TotalPosts AS ActiveUserPostCount,
    mau.TotalComments AS ActiveUserCommentCount
FROM
    TagCounts tc
JOIN
    MostActiveUsers mau ON mau.ActivityRank <= 5
WHERE
    tc.PostCount > 0
ORDER BY
    tc.PostCount DESC,
    mau.TotalPosts DESC;
