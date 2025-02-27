WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2) - SUM(v.VoteTypeId = 3), 0) AS Score, 
        RANK() OVER (ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        p.Id
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.CreationDate,
        rp.ViewCount,
        rp.CommentCount,
        rp.Score
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 10 -- Top 10 most recent questions
),
PostWithTags AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.Body,
        tp.Tags,
        tp.CreationDate,
        tp.ViewCount,
        tp.CommentCount,
        tp.Score,
        STRING_AGG(t.TagName, ', ') AS TagList
    FROM 
        TopPosts tp
    JOIN 
        LATERAL STRING_TO_ARRAY(tp.Tags, ',') AS tag_array ON TRUE 
    JOIN 
        Tags t ON t.TagName = TRIM(BOTH ' ' FROM REPLACE(tag_array, '<', ''))
    GROUP BY 
        tp.PostId
)
SELECT 
    pw.PostId,
    pw.Title,
    pw.Body,
    pw.TagList,
    pw.CreationDate,
    pw.ViewCount,
    pw.CommentCount,
    pw.Score,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation
FROM 
    PostWithTags pw
JOIN 
    Users u ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = pw.PostId)
ORDER BY 
    pw.Score DESC, pw.CreationDate DESC;
