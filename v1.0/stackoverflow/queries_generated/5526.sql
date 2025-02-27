WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.Score,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVoteCount,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS RankInTag
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
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
    Users U ON tp.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = U.Id)
ORDER BY 
    tp.RankInTag, tp.Score DESC;
