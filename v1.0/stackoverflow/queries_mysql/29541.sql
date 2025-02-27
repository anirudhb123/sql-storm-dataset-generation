
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.Body,
        u.DisplayName AS Owner,
        COUNT(a.Id) AS AnswerCount,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        @row_number := IF(@current_post_id = p.Id, @row_number + 1, 1) AS rn,
        @current_post_id := p.Id
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id 
    LEFT JOIN 
        Comments c ON c.PostId = p.Id 
    LEFT JOIN 
        Votes v ON v.PostId = p.Id 
    CROSS JOIN 
        (SELECT @row_number := 0, @current_post_id := NULL) AS init
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.Tags, p.Body
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
        rp.rn = 1 
)
SELECT 
    fp.Title,
    fp.Owner,
    fp.AnswerCount,
    fp.CommentCount,
    fp.UpVotes,
    fp.DownVotes,
    LENGTH(REPLACE(REPLACE(fp.Tags, '><', '>'), '<', '')) - LENGTH(REPLACE(fp.Tags, '>', '')) + 1 AS TagCount, 
    LENGTH(fp.Body) AS BodyLength, 
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
LIMIT 10;
