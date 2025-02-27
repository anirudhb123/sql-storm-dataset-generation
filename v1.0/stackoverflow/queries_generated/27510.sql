WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerName,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes, -- Only counting upvotes
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes, -- Only counting downvotes
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
        JOIN Users u ON p.OwnerUserId = u.Id
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        OwnerName,
        CommentCount,
        UpVotes,
        DownVotes
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 3 -- Top 3 posts per user
),
TagsData AS (
    SELECT 
        pt.PostId,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        PostLinks pt
        JOIN Tags t ON pt.RelatedPostId = t.Id
    GROUP BY 
        pt.PostId
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Body,
    tp.CreationDate,
    tp.OwnerName,
    tp.CommentCount,
    tp.UpVotes,
    tp.DownVotes,
    COALESCE(td.Tags, 'No Tags') AS Tags
FROM 
    TopPosts tp
    LEFT JOIN TagsData td ON tp.PostId = td.PostId
ORDER BY 
    tp.CreationDate DESC;
