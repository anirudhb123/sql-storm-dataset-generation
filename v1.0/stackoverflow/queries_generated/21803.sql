WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year' 
        AND p.ViewCount > 100
), 
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(COUNT(c.Id), 0) AS CommentCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    GROUP BY 
        u.Id, u.DisplayName
), 
PostMetrics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        ua.UpVotes,
        ua.DownVotes,
        ua.CommentCount,
        CASE 
            WHEN ua.UpVotes - ua.DownVotes > 0 THEN 'Positive' 
            WHEN ua.UpVotes - ua.DownVotes < 0 THEN 'Negative'
            ELSE 'Neutral'
        END AS UserSentiment
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserActivity ua ON rp.OwnerUserId = ua.UserId
)

SELECT 
    pm.PostId,
    pm.Title,
    pm.Score,
    pm.UserSentiment,
    ph.Comment AS LastEditComment,
    STRING_AGG(DISTINCT pt.Name, ', ') AS PostHistoryTypes 
FROM 
    PostMetrics pm
LEFT JOIN 
    PostHistory ph ON pm.PostId = ph.PostId 
    AND ph.CreationDate = (SELECT MAX(CreationDate) FROM PostHistory WHERE PostId = pm.PostId)
LEFT JOIN 
    PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
WHERE 
    pm.Score > 0
GROUP BY 
    pm.PostId, pm.Title, pm.Score, ph.Comment
ORDER BY 
    pm.Score DESC
LIMIT 50;

This query includes:
1. Common Table Expressions (CTEs) to structure the data in ranked posts and user activity.
2. Window functions to rank posts based on the score.
3. Correlated subqueries to find the last edit comment for each post.
4. String aggregation to provide a list of associated post history types.
5. Use of CASE statements to derive user sentiment based on their voting behavior. 
6. Complex filtering and aggregations to provide insight into the posts with a score greater than 0.
