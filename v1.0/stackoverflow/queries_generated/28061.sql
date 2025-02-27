WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS Author,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY COUNT(c.Id) DESC, p.Score DESC) AS RankInTag
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, u.DisplayName
),
TopPostsByTag AS (
    SELECT 
        Tags,
        ARRAY_AGG(PostId) AS TopPostIds
    FROM 
        RankedPosts
    WHERE 
        RankInTag <= 5
    GROUP BY 
        Tags
)
SELECT 
    t.Tags,
    p.PostId,
    p.Title,
    p.Author,
    p.CreationDate,
    p.CommentCount,
    p.UpVotes,
    p.DownVotes
FROM 
    TopPostsByTag t
JOIN 
    RankedPosts p ON p.PostId = ANY(t.TopPostIds)
ORDER BY 
    t.Tags, p.UpVotes DESC, p.CommentCount DESC;
