WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COALESCE(SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id), 0) AS UpvoteCount,
        COALESCE(SUM(v.VoteTypeId = 3) OVER (PARTITION BY p.Id), 0) AS DownvoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
RecentPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.UpvoteCount,
        rp.DownvoteCount,
        CASE 
            WHEN rp.PostRank = 1 THEN 'Latest'
            WHEN rp.PostRank <= 5 THEN 'Recent'
            ELSE 'Older'
        END AS PostCategory
    FROM 
        RankedPosts rp
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(c.Text, '; ') AS AllComments
    FROM 
        Comments c
    GROUP BY 
        c.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.UpvoteCount,
    rp.DownvoteCount,
    pc.CommentCount,
    pc.AllComments,
    rp.PostCategory,
    CASE 
        WHEN rp.Score >= 10 THEN 'High Score'
        WHEN rp.Score BETWEEN 5 AND 9 THEN 'Medium Score'
        ELSE 'Low Score'
    END AS ScoreCategory,
    CASE 
        WHEN rp.ViewCount IS NULL THEN 'No Views Yet'
        WHEN rp.ViewCount = 0 THEN 'Unseen'
        ELSE 'Seen'
    END AS ViewStatus
FROM 
    RecentPosts rp
LEFT JOIN 
    PostComments pc ON rp.PostId = pc.PostId
WHERE 
    rp.PostCategory = 'Recent'
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC
LIMIT 100;

-- Additionally, select posts with complex predicates, involving NULL and string expressions
SELECT 
    p.Title,
    CASE 
        WHEN p.OwnerDisplayName IS NULL THEN 'Anonymous'
        ELSE p.OwnerDisplayName
    END AS OwnerDisplayName,
    COALESCE(NULLIF(TRIM(p.Tags), ''), 'No Tags') AS Tags,
    STRING_AGG(DISTINCT pt.Name, ', ') AS PostTypeName,
    CASE 
        WHEN p.CreationDate < NOW() - INTERVAL '1 year' THEN 'Archived'
        ELSE 'Active'
    END AS PostStatus
FROM 
    Posts p
LEFT JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
WHERE 
    p.Score >= (SELECT AVG(Score) FROM Posts WHERE Score IS NOT NULL) AND
    p.CreationDate >= NOW() - INTERVAL '2 years'
GROUP BY 
    p.Title, p.OwnerDisplayName, p.Tags, p.CreationDate
HAVING 
    COUNT(DISTINCT p.Id) >= 1
ORDER BY 
    OwnerDisplayName, p.CreationDate DESC;
