WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    INNER JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1
),
PostActivity AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerUserId,
        rp.OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Comments c ON rp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON rp.PostId = v.PostId
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, rp.Score, rp.ViewCount, rp.OwnerUserId, rp.OwnerDisplayName
),
FinalResults AS (
    SELECT 
        pa.*,
        CASE 
            WHEN pa.VoteCount > 100 THEN 'Highly Voted'
            WHEN pa.VoteCount BETWEEN 50 AND 100 THEN 'Moderately Voted'
            ELSE 'Less Voted'
        END AS VoteCategory
    FROM 
        PostActivity pa
    WHERE 
        pa.RankByScore = 1
)
SELECT 
    fr.PostId,
    fr.Title,
    fr.CreationDate,
    fr.Score,
    fr.ViewCount,
    fr.OwnerUserId,
    fr.OwnerDisplayName,
    fr.CommentCount,
    fr.VoteCount,
    fr.VoteCategory
FROM 
    FinalResults fr
ORDER BY 
    fr.Score DESC, fr.ViewCount DESC
LIMIT 10;
