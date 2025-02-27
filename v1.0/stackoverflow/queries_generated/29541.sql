WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.Body,
        u.DisplayName AS Owner,
        COUNT(a.Id) AS AnswerCount,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id -- Answers
    LEFT JOIN 
        Comments c ON c.PostId = p.Id -- Comments
    LEFT JOIN 
        Votes v ON v.PostId = p.Id -- Votes
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Tags,
        rp.Body,
        rp.Owner,
        rp.AnswerCount,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1 -- Selecting distinct questions
)
SELECT 
    fp.Title,
    fp.Owner,
    fp.AnswerCount,
    fp.CommentCount,
    fp.UpVotes,
    fp.DownVotes,
    ARRAY_LENGTH(string_to_array(fp.Tags, '><'), 1) AS TagCount, -- Count distinct tags
    LENGTH(fp.Body) AS BodyLength, -- Length of the body
    CASE 
        WHEN fp.UpVotes > fp.DownVotes THEN 'Positive' 
        WHEN fp.UpVotes < fp.DownVotes THEN 'Negative' 
        ELSE 'Neutral' 
    END AS Sentiment
FROM 
    FilteredPosts fp
ORDER BY 
    fp.UpVotes DESC, 
    fp.AnswerCount DESC
LIMIT 10; -- Get top 10 questions based on upvotes
