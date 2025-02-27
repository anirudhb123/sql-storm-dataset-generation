WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Body,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVoteCount,
        SUM(v.VoteTypeId = 3) AS DownVoteCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><') AS tag_id ON TRUE
    LEFT JOIN 
        Tags t ON t.Id = tag_id
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
PostStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Body,
        rp.CommentCount,
        rp.UpVoteCount,
        rp.DownVoteCount,
        rp.Tags,
        DENSE_RANK() OVER (ORDER BY rp.UpVoteCount - rp.DownVoteCount DESC) AS PopularityRank
    FROM 
        RankedPosts rp
),
TopPosts AS (
    SELECT 
        p.*,
        CASE 
            WHEN p.PopularityRank <= 10 THEN 'Top 10'
            ELSE 'Others'
        END AS PopularityCategory
    FROM 
        PostStats p
)
SELECT 
    p.PostId,
    p.Title,
    p.CreationDate,
    p.CommentCount,
    p.UpVoteCount,
    p.DownVoteCount,
    p.Tags,
    p.PopularityCategory
FROM 
    TopPosts p
ORDER BY 
    p.PopularityRank, p.CommentCount DESC;
