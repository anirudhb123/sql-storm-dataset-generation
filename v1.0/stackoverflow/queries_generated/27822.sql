WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        STRING_AGG(t.TagName, ', ') AS Tags,
        u.DisplayName AS OwnerDisplayName,
        COUNT(a.Id) AS AnswerCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '>')::int[])
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.Score, u.DisplayName
),

TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        rp.Tags,
        rp.OwnerDisplayName,
        rp.AnswerCount,
        rp.UpVotes,
        rp.DownVotes,
        DENSE_RANK() OVER (ORDER BY rp.Score DESC) AS ScoreRank
    FROM 
        RankedPosts rp
    WHERE 
        rp.OwnerPostRank = 1
)

SELECT 
    t.Title,
    t.ViewCount,
    t.Score,
    t.Tags,
    t.OwnerDisplayName,
    t.AnswerCount,
    t.UpVotes,
    t.DownVotes
FROM 
    TopPosts t
WHERE 
    t.ScoreRank <= 10
ORDER BY 
    t.Score DESC, t.ViewCount DESC;
