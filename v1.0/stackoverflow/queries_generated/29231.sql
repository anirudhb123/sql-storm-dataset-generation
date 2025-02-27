WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Tags,
        COUNT(v.Id) AS VoteCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagList,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        STRING_TO_ARRAY(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags) - 2), '><') AS tag_arr ON true
    LEFT JOIN 
        Tags t ON tag_arr.value = t.TagName
    WHERE 
        p.PostTypeId = 1 -- Considering only Questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.Score, p.ViewCount, p.Tags
), 
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        Body, 
        CreationDate, 
        Score, 
        ViewCount, 
        TagList, 
        VoteCount
    FROM 
        RankedPosts
    WHERE 
        rn = 1 
    ORDER BY 
        Score DESC, 
        ViewCount DESC 
    LIMIT 10
), 
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
    HAVING 
        TotalPosts > 0
)
SELECT 
    tp.Title,
    tp.Body,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.TagList,
    tp.VoteCount,
    ur.DisplayName AS OwnerDisplayName,
    ur.Reputation AS OwnerReputation,
    ur.TotalQuestions,
    ur.TotalAnswers
FROM 
    TopPosts tp
JOIN 
    UserReputation ur ON tp.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = ur.UserId)
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
