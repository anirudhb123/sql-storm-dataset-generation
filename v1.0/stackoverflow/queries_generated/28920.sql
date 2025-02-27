WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerName,
        p.CreationDate,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        DENSE_RANK() OVER (ORDER BY COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) - COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) DESC) AS VoteRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1   -- Only Questions
    GROUP BY
        p.Id, p.Title, p.Body, p.Tags, u.DisplayName, p.CreationDate
),
TagDetails AS (
    SELECT 
        t.TagName,
        COUNT(pt.PostId) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts pt ON pt.Tags LIKE '%' || t.TagName || '%'
    WHERE 
        pt.PostTypeId = 1
    GROUP BY 
        t.TagName
),
HighVotePosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.OwnerName,
        rp.CreationDate,
        rp.UpVotes,
        rp.DownVotes,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.VoteRank <= 10  -- Select top 10 ranked posts
)
SELECT 
    h.PostId,
    h.Title,
    h.Body,
    h.OwnerName,
    h.CreationDate,
    h.UpVotes,
    h.DownVotes,
    h.CommentCount,
    td.TagName,
    td.PostCount
FROM 
    HighVotePosts h
LEFT JOIN 
    TagDetails td ON h.Title LIKE '%' || td.TagName || '%'  -- Considering title reflection of tags
ORDER BY 
    h.UpVotes - h.DownVotes DESC,  -- Order by net votes
    h.CreationDate DESC;  -- Order by the most recent posts
