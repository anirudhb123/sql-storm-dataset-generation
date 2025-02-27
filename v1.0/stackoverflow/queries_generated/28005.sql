WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Body,
        p.CreationDate, 
        p.ViewCount, 
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  -- Only questions
),
CommentStatistics AS (
    SELECT 
        PostId,
        COUNT(*) AS CommentCount, 
        MAX(CreationDate) AS LastCommentDate
    FROM 
        Comments 
    GROUP BY 
        PostId
),
VoteStatistics AS (
    SELECT 
        PostId, 
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes 
    GROUP BY 
        PostId
),
TaggedPosts AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS tagName ON TRUE
    JOIN 
        Tags t ON tagName = t.TagName
    GROUP BY 
        p.Id
)
SELECT 
    rp.PostId, 
    rp.Title, 
    rp.Body,
    rp.CreationDate, 
    rp.ViewCount, 
    rp.OwnerDisplayName,
    cs.CommentCount,
    cs.LastCommentDate,
    vs.UpVotes,
    vs.DownVotes,
    tp.Tags
FROM 
    RankedPosts rp
LEFT JOIN 
    CommentStatistics cs ON rp.PostId = cs.PostId
LEFT JOIN 
    VoteStatistics vs ON rp.PostId = vs.PostId
LEFT JOIN 
    TaggedPosts tp ON rp.PostId = tp.PostId
WHERE 
    rp.rn = 1  -- Get latest post for each user
ORDER BY 
    rp.CreationDate DESC
LIMIT 10;  -- Benchmarking against the latest 10 questions
