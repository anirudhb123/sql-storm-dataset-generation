WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND -- Only questions
        p.CreationDate >= NOW() - INTERVAL '1 year' -- Questions posted in the last year
),
TopPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.Tags
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankByScore = 1 -- Get the top-scoring question per tag
),
PostWithUserInfo AS (
    SELECT 
        tp.Id AS PostId,
        tp.Title,
        tp.CreationDate,
        tp.Score,
        tp.ViewCount,
        tp.AnswerCount,
        u.DisplayName AS OwnerName,
        u.Reputation AS OwnerReputation
    FROM 
        TopPosts tp
    JOIN 
        Users u ON tp.OwnerUserId = u.Id
),
VotesPerPost AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotesCount,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotesCount
    FROM 
        Votes v
    GROUP BY 
        v.PostId
)
SELECT 
    pwui.PostId,
    pwui.Title,
    pwui.CreationDate,
    pwui.Score,
    pwui.ViewCount,
    pwui.AnswerCount,
    pwui.OwnerName,
    pwui.OwnerReputation,
    COALESCE(vpp.UpVotesCount, 0) AS UpVotesCount,
    COALESCE(vpp.DownVotesCount, 0) AS DownVotesCount
FROM 
    PostWithUserInfo pwui
LEFT JOIN 
    VotesPerPost vpp ON pwui.PostId = vpp.PostId
ORDER BY 
    pwui.Score DESC, pwui.ViewCount DESC;
