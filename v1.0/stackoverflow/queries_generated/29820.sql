WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        ARRAY_AGG(t.TagName) AS Tags,
        COALESCE(v.upvote_count, 0) AS UpVotes,
        COALESCE(c.comment_count, 0) AS CommentCount,
        COALESCE(a.answer_count, 0) AS AnswerCount,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        LATERAL (
            SELECT
                COUNT(*) AS upvote_count
            FROM 
                Votes v
            WHERE 
                v.PostId = p.Id AND v.VoteTypeId = 2  -- Upvote
        ) v ON true
    LEFT JOIN 
        LATERAL (
            SELECT
                COUNT(*) AS comment_count
            FROM 
                Comments c
            WHERE 
                c.PostId = p.Id
        ) c ON true
    LEFT JOIN 
        LATERAL (
            SELECT
                COUNT(*) AS answer_count
            FROM 
                Posts a
            WHERE 
                a.ParentId = p.Id AND a.PostTypeId = 2  -- Answer
        ) a ON true
    LEFT JOIN 
        Tags t ON t.ExcerptPostId = p.Id OR t.WikiPostId = p.Id
    WHERE 
        p.PostTypeId = 1  -- Considering only Questions
    GROUP BY 
        p.Id, p.Title, p.Body, v.upvote_count, c.comment_count, a.answer_count
    ORDER BY 
        p.CreationDate DESC
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.UpVotes,
        rp.CommentCount,
        rp.AnswerCount,
        COUNT(ph.Id) AS EditCount,  -- Count of edits for each post
        MAX(ph.CreationDate) AS LastEditDate  -- Most recent edit date
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistory ph ON ph.PostId = rp.PostId AND ph.PostHistoryTypeId IN (4, 5, 6)  -- Edit Title, Body, Tags
    GROUP BY 
        rp.PostId, rp.Title, rp.Body, rp.Tags, rp.UpVotes, rp.CommentCount, rp.AnswerCount
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Body,
    fp.Tags,
    fp.UpVotes,
    fp.CommentCount,
    fp.AnswerCount,
    fp.EditCount,
    fp.LastEditDate,
    RANK() OVER (ORDER BY fp.UpVotes DESC, fp.CommentCount DESC, fp.AnswerCount DESC) AS PopularityRank  -- Popularity ranking
FROM 
    FilteredPosts fp
WHERE 
    fp.EditCount > 0  -- Filter for posts that have been edited
ORDER BY 
    PopularityRank, LastEditDate DESC;
