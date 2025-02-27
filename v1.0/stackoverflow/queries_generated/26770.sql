WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        COALESCE(p.AnswerCount, 0) AS AnswerCount,
        COALESCE(p.ViewCount, 0) AS ViewCount,
        COALESCE(v.UpVotes, 0) - COALESCE(v.DownVotes, 0) AS Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COALESCE(p.ViewCount, 0) DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
),

TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.Score,
        rp.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    WHERE 
        rp.UserPostRank <= 5
)

SELECT 
    tp.Title,
    tp.Body,
    STRING_AGG(t.TagName, ', ') AS RelatedTags,
    tp.Score,
    tp.ViewCount,
    tp.OwnerDisplayName,
    tp.Reputation 
FROM 
    TopPosts tp
LEFT JOIN 
    (SELECT 
         Id, 
         UNNEST(string_to_array(substring(Tags, 2, length(Tags) - 2), '> <'))::varchar AS TagName 
     FROM 
         Posts) t ON tp.PostId = t.Id
GROUP BY 
    tp.PostId, tp.Title, tp.Body, tp.Score, tp.ViewCount, tp.OwnerDisplayName, tp.Reputation
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
