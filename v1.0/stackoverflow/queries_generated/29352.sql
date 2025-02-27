WITH RecursiveTags AS (
    SELECT
        Id,
        TagName,
        Count,
        ExcerptPostId,
        WikiPostId,
        IsModeratorOnly,
        IsRequired,
        1 AS Level
    FROM Tags
    WHERE TagName IS NOT NULL

    UNION ALL

    SELECT
        t.Id,
        t.TagName,
        t.Count,
        t.ExcerptPostId,
        t.WikiPostId,
        t.IsModeratorOnly,
        t.IsRequired,
        Level + 1
    FROM Tags t
    JOIN RecursiveTags rt ON t.Count > rt.Count -- arbitrary relationship for recursion
    WHERE Level < 5 -- limit recursion depth
),

PostVotes AS (
    SELECT
        p.Id AS PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id
),

UserBadges AS (
    SELECT
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),

PostDetails AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Body,
        pt.Name AS PostType,
        COALESCE(tag.TagName, 'No Tag') AS MainTag,
        pv.UpVotes,
        pv.DownVotes,
        pv.TotalVotes,
        ub.BadgeCount,
        ub.BadgeNames
    FROM Posts p
    JOIN PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN PostVotes pv ON p.Id = pv.PostId
    LEFT JOIN RecursiveTags tag ON tag.Id = p.Tags::int -- Assuming Tags stored as comma-separated integers
    LEFT JOIN UserBadges ub ON p.OwnerUserId = ub.UserId
)

SELECT
    pd.PostId,
    pd.Title,
    pd.Body,
    pd.PostType,
    pd.MainTag,
    pd.UpVotes,
    pd.DownVotes,
    pd.TotalVotes,
    pd.BadgeCount,
    pd.BadgeNames
FROM PostDetails pd
WHERE pd.UpVotes > 10  -- Filtering for posts with more than 10 upvotes
ORDER BY pd.TotalVotes DESC
LIMIT 20;  -- Limiting the result to top 20 posts
