WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN,
        COALESCE(v.VoteTypeId, 0) AS LastVoteType,
        CASE 
            WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 
            ELSE 0 
        END AS HasAcceptedAnswer
    FROM 
        Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 1  -- VoteTypeId = AcceptedByOriginator
    WHERE 
        p.PostTypeId = 1  -- Only Questions
), 
PostTags AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(t.TagName, ', ') AS TagsList
    FROM 
        Posts p
    JOIN UNNEST(string_to_array(p.Tags, '><')) t(TagName) ON true
    GROUP BY 
        p.Id
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    u.DisplayName,
    up.PostId,
    up.Title,
    up.CreationDate,
    up.Score,
    up.ViewCount,
    pt.TagsList,
    CASE 
        WHEN a.AnswerId IS NOT NULL THEN 'Accepted Answer Exists'
        ELSE 'No Accepted Answer'
    END AS Status,
    ua.TotalPosts,
    ua.TotalBadges
FROM 
    RankedPosts up
LEFT JOIN (
    SELECT 
        p.Id AS AnswerId, 
        p.ParentId
    FROM 
        Posts p 
    WHERE 
        p.PostTypeId = 2  -- Only Answers
) a ON up.PostId = a.ParentId
JOIN Users u ON up.OwnerUserId = u.Id
JOIN PostTags pt ON up.PostId = pt.PostId
JOIN UserActivity ua ON u.Id = ua.UserId
WHERE 
    up.RN = 1  -- Only the latest post per user
    AND (up.Score IS NOT NULL OR up.ViewCount > 100)  -- Complex predicate
ORDER BY 
    up.Score DESC,
    up.ViewCount DESC
LIMIT 50;
