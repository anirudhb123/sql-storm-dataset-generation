
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.Score,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        @row_number := IF(@prev_tag = p.Tags, @row_number + 1, 1) AS RankInTag,
        @prev_tag := p.Tags
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    CROSS JOIN 
        (SELECT @row_number := 0, @prev_tag := '') AS vars
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title, p.Tags, p.CreationDate, p.Score
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Tags,
        rp.CreationDate,
        rp.Score,
        rp.AnswerCount,
        rp.UpVoteCount,
        rp.DownVoteCount,
        rp.RankInTag
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankInTag <= 5
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Tags,
    tp.CreationDate,
    tp.Score,
    tp.AnswerCount,
    tp.UpVoteCount,
    tp.DownVoteCount,
    U.DisplayName AS OwnerDisplayName,
    U.Reputation AS OwnerReputation
FROM 
    TopPosts tp
JOIN 
    Users U ON U.Id IN (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId)
ORDER BY 
    tp.RankInTag, tp.Score DESC;
