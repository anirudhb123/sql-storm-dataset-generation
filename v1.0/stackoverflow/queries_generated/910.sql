WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
), 
PostAnalytics AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id), 0) AS CommentCount,
        DENSE_RANK() OVER (ORDER BY p.Score DESC, p.CreationDate ASC) AS ScoreRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
), 
TopPosts AS (
    SELECT 
        pa.*,
        ua.DisplayName,
        ua.Reputation
    FROM 
        PostAnalytics pa
    JOIN 
        UserActivity ua ON pa.Id = ua.UserId
    WHERE 
        pa.ScoreRank <= 10
)

SELECT 
    tp.Title,
    tp.CreatedDate,
    tp.Score,
    tp.ViewCount,
    tp.CommentCount,
    tp.DisplayName AS OwnerName,
    tp.Reputation,
    pt.Name AS PostTypeName,
    COALESCE(JSON_AGG(DISTINCT t.TagName), '[]') AS RelatedTags
FROM 
    TopPosts tp
LEFT JOIN 
    PostTypes pt ON tp.PostTypeId = pt.Id
LEFT JOIN 
    Tags t ON tp.Id = t.ExcerptPostId
GROUP BY 
    tp.Id, tp.Title, tp.CreationDate, tp.Score, tp.ViewCount, tp.CommentCount, tp.DisplayName, tp.Reputation, pt.Name
ORDER BY 
    tp.Score DESC, tp.CreationDate ASC
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY;
