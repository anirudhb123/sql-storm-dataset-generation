WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpvoteCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownvoteCount,
        COALESCE((SELECT SUM(b.Class) FROM Badges b WHERE b.UserId = p.OwnerUserId), 0) AS OwnerBadges,
        (SELECT STRING_AGG(t.TagName, ', ') FROM Tags t WHERE t.Id IN (SELECT UNNEST(string_to_array(p.Tags, '>'))::int)) AS RelatedTags
    FROM 
        Posts p 
    WHERE 
        p.Score > 0 
        AND p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN p.OwnerUserId = u.Id THEN 1 ELSE 0 END) AS PostsCount,
        SUM(c.Score) AS TotalCommentScore,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBountyEarned
    FROM 
        Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON u.Id = v.UserId AND v.PostId = p.Id
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id
),
TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        AVG(p.Score) AS AverageScore
    FROM 
        Tags t
    JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.RankScore,
    rp.CommentCount,
    rp.UpvoteCount,
    rp.DownvoteCount,
    ue.DisplayName AS PostOwner,
    ue.PostsCount,
    ue.TotalCommentScore,
    ue.TotalBountyEarned,
    ts.TagName,
    ts.PostCount,
    ts.AverageScore
FROM 
    RankedPosts rp
LEFT JOIN UserEngagement ue ON rp.OwnerUserId = ue.UserId
LEFT JOIN TagStatistics ts ON rp.RelatedTags LIKE '%' || ts.TagName || '%'
WHERE 
    (rp.CommentCount > 5 OR rp.Score > 50)
    AND (ue.TotalBountyEarned > 0 OR ue.PostsCount >= 2)
ORDER BY 
    rp.RankScore ASC NULLS LAST,
    ue.TotalCommentScore DESC
LIMIT 50;
This SQL query demonstrates multiple advanced features like Common Table Expressions (CTEs), window functions, correlated subqueries, and NULL logic. It returns a curated view of posts, ranked by score, while also displaying aggregate engagement data from their respective owners and insights related to the tags involved. Complex predicates ensure that only the most relevant data is pulled, showcasing how SQL can be intricate yet powerful.
