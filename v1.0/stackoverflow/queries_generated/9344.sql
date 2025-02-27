WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(a.Id) AS AnswerCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS RankByScore,
        ARRAY_AGG(t.TagName) AS Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id
    LEFT JOIN 
        STRING_TO_ARRAY(substring(p.Tags, 2, length(p.Tags)-2), '><') AS tagName ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tagName
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, u.DisplayName
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.RankByScore,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 2) AS UpVotes,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 3) AS DownVotes,
    (SELECT COUNT(*) FROM PostHistory ph WHERE ph.PostId = rp.PostId AND ph.PostHistoryTypeId IN (10, 11)) AS CloseActionCount,
    rp.Tags
FROM 
    RankedPosts rp
WHERE 
    rp.RankByScore <= 5
ORDER BY 
    rp.RankByScore, rp.Score DESC;
