WITH RankedPosts AS (
    SELECT 
        p.Title,
        p.Score,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, u.DisplayName
),
TopPosts AS (
    SELECT 
        Title, 
        Score, 
        CreationDate, 
        OwnerDisplayName, 
        CommentCount, 
        UpVoteCount, 
        DownVoteCount
    FROM 
        RankedPosts
    WHERE 
        PostRank = 1
    ORDER BY 
        Score DESC
    LIMIT 10
)
SELECT 
    tp.Title,
    tp.OwnerDisplayName,
    tp.Score,
    tp.CommentCount,
    tp.UpVoteCount,
    tp.DownVoteCount,
    COALESCE(SUBSTRING_INDEX(t.TagName, ',', 1), 'No Tags') AS PrimaryTag
FROM 
    TopPosts tp
LEFT JOIN 
    (SELECT 
        Tags.TagName, 
        Posts.Id 
     FROM 
        Posts 
     JOIN 
        STRING_AGG(Tags.TagName, ',') AS TagNames 
     ON 
        Posts.Tags ILIKE '%' || Tags.TagName || '%' 
     GROUP BY 
        Tags.TagName, Posts.Id) t ON tp.Title ILIKE '%' || t.Id || '%';
