WITH RecursivePostHistory AS (
    SELECT
        ph.Id AS HistoryId,
        ph.PostId,
        ph.CreationDate,
        ph.PostHistoryTypeId,
        ph.UserId,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS RecentActivityRank
    FROM
        PostHistory ph
),
UserPostStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS TotalQuestions,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalAnswers,
        MAX(u.Reputation) AS MaxReputation
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY
        u.Id
),
PostMetadata AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.AcceptedAnswerId,
        p.ViewCount,
        p.AnswerCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties
    FROM
        Posts p
    LEFT JOIN
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 -- BountyStart
    GROUP BY
        p.Id
),
RelevantTags AS (
    SELECT
        t.Id AS TagId,
        t.TagName,
        COUNT(pt.PostId) AS TagUsage
    FROM
        Tags t
    LEFT JOIN
        Posts pt ON pt.Tags LIKE '%' || t.TagName || '%'
    GROUP BY
        t.Id
    HAVING
        COUNT(pt.PostId) > 5 -- only consider tags used in more than 5 posts
)
SELECT
    u.DisplayName,
    u.TotalPosts,
    u.TotalQuestions,
    u.TotalAnswers,
    COALESCE(ph.RecentActivityRank, 0) AS RecentActivityRank,
    COALESCE(pm.Title, 'No Title') AS PostTitle,
    pm.ViewCount,
    pm.AcceptedAnswerId,
    pm.TotalBounties,
    STRING_AGG(rt.TagName, ', ') AS PopularTags
FROM
    UserPostStats u
LEFT JOIN
    RecursivePostHistory ph ON u.UserId = ph.UserId AND ph.RecentActivityRank = 1
LEFT JOIN
    PostMetadata pm ON ph.PostId = pm.PostId
LEFT JOIN
    RelevantTags rt ON pm.PostId IN (SELECT p.Id FROM Posts p WHERE p.Tags LIKE '%' || rt.TagName || '%')
WHERE
    u.MaxReputation IS NOT NULL
    AND (u.TotalPosts > 0 OR u.TotalQuestions > 0)
GROUP BY
    u.UserId, u.DisplayName, u.TotalPosts, u.TotalQuestions, u.TotalAnswers, pm.Title, pm.ViewCount, pm.AcceptedAnswerId, pm.TotalBounties
ORDER BY
    u.TotalPosts DESC, u.TotalQuestions DESC;
