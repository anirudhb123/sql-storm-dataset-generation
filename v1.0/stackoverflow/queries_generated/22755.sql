WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) OVER (PARTITION BY p.Id) AS UpvoteCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) OVER (PARTITION BY p.Id) AS DownvoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.UpvoteCount,
    rp.DownvoteCount,
    COALESCE(ut.DisplayName, 'Community User') AS UserDisplayName,
    pt.Name AS PostTypeName,
    PH.RevisionGUID,
    CASE 
        WHEN rp.UserPostRank = 1 THEN 'Latest Post'
        ELSE 'Older Post'
    END AS PostClassification,
    (
        SELECT COUNT(*) 
        FROM Comments c 
        WHERE c.PostId = rp.PostId AND c.CreationDate > CURRENT_DATE - INTERVAL '30 days'
    ) AS RecentCommentCount,
    (
        SELECT ARRAY_AGG(t.TagName) 
        FROM Tags t
        JOIN LATERAL UNNEST(string_to_array(rp.Title, ' ')) AS keyword ON keyword = t.TagName
        WHERE t.Count > 0
    ) AS RelatedTags,
    (
        SELECT DISTINCT 'Badge: ' || b.Name 
        FROM Badges b 
        WHERE b.UserId = rp.OwnerUserId 
        AND (b.Class = 1 OR b.Class = 2)
        FOR JSON PATH
    ) AS UserBadges
FROM 
    RankedPosts rp
LEFT JOIN 
    Users ut ON rp.OwnerUserId = ut.Id
JOIN 
    PostTypes pt ON rp.PostTypeId = pt.Id
LEFT JOIN 
    PostHistory PH ON rp.PostId = PH.PostId AND PH.PostHistoryTypeId IN (10, 11, 12)
WHERE 
    rp.UpvoteCount > rp.DownvoteCount 
    OR (rp.UpvoteCount = 0 AND rp.DownvoteCount IS NULL)
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC
LIMIT 100
OFFSET 0;
