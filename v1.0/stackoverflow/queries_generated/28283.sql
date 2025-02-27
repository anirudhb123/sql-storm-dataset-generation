WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Only consider Questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.CreationDate,
        rp.CommentCount,
        rp.AnswerCount,
        rp.UpVoteCount,
        rp.DownVoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5 -- Limit to the latest 5 questions per user
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Body,
    fp.Tags,
    fp.CreationDate,
    fp.CommentCount,
    fp.AnswerCount,
    fp.UpVoteCount,
    fp.DownVoteCount,
    (fp.UpVoteCount - fp.DownVoteCount) AS Score
FROM 
    FilteredPosts fp
WHERE 
    fp.CommentCount > 5 -- Only consider posts with more than 5 comments
ORDER BY 
    Score DESC, CreationDate DESC -- Order by Score and then by CreationDate
LIMIT 10; -- Limit the final result set to 10 posts
