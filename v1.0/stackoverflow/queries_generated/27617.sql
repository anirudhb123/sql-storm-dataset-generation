WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Body,
        p.Tags,
        COUNT(a.Id) AS AnswerCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND p.PostTypeId = 1  -- Answers for questions
    LEFT JOIN 
        Comments c ON p.Id = c.PostId                     -- Comments for posts
    LEFT JOIN 
        Votes v ON p.Id = v.PostId                         -- Votes on posts
    WHERE 
        p.PostTypeId = 1                                   -- Only questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Body, p.Tags
),

FilteredPosts AS (
    SELECT 
        rp.*,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        (SELECT STRING_AGG(DISTINCT t.TagName, ', ') 
         FROM Tags t 
         WHERE t.Id = ANY(string_to_array(substr(rp.Tags, 2, length(rp.Tags) - 2), '><')::int[])) AS TagList
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    WHERE 
        rp.PostRank = 1                                 -- Only most recent post per user
        AND rp.AnswerCount > 5                         -- Filter out questions with less than 5 answers
),

DetailedPostInfo AS (
    SELECT 
        fp.PostId,
        fp.Title,
        fp.CreationDate,
        fp.OwnerDisplayName,
        fp.OwnerReputation,
        fp.AnswerCount,
        fp.CommentCount,
        fp.VoteCount,
        fp.TagList,
        ph.CreationDate AS LastEditDate,
        ph.Comment AS EditComment
    FROM 
        FilteredPosts fp
    LEFT JOIN 
        PostHistory ph ON fp.PostId = ph.PostId AND ph.PostHistoryTypeId IN (4, 5, 24)  -- Title, Body edits, or Suggested Edits
)

SELECT 
    d.Title,
    d.OwnerDisplayName,
    d.OwnerReputation,
    d.AnswerCount,
    d.CommentCount,
    d.VoteCount,
    d.TagList,
    d.LastEditDate,
    d.EditComment
FROM 
    DetailedPostInfo d
ORDER BY 
    d.OwnerReputation DESC,                              -- High reputation first
    d.AnswerCount DESC,                                  -- More answers first
    d.CreationDate DESC;                                 -- More recent posts first
