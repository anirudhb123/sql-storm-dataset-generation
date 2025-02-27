
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.CreationDate,
        p.Title,
        p.Score,
        p.ViewCount,
        @row_num := IF(@prev_user = p.OwnerUserId, @row_num + 1, 1) AS OwnerPostRank,
        @prev_user := p.OwnerUserId
    FROM 
        Posts p, (SELECT @row_num := 0, @prev_user := NULL) AS vars
    WHERE 
        p.PostTypeId = 1 
    ORDER BY 
        p.OwnerUserId, p.CreationDate DESC
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostHistoryAnalysis AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstEditDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (4, 5, 6) THEN 1 END) AS EditCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate > NOW() - INTERVAL 1 YEAR
    GROUP BY 
        ph.PostId
),
VisiblePosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        pha.FirstEditDate,
        pha.EditCount,
        pha.CloseCount,
        @post_rank := @post_rank + 1 AS PostRank
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    LEFT JOIN 
        PostHistoryAnalysis pha ON rp.PostId = pha.PostId, (SELECT @post_rank := 0) AS vars
    WHERE 
        rp.OwnerPostRank = 1 
    ORDER BY 
        rp.Score DESC, rp.ViewCount DESC
),
FinalResults AS (
    SELECT 
        vp.*,
        CASE 
            WHEN vp.CloseCount > 0 THEN 'Closed'
            WHEN vp.EditCount > 0 THEN 'Edited'
            ELSE 'Original'
        END AS PostStatus,
        CASE 
            WHEN vp.OwnerReputation >= 1000 THEN 'Experienced'
            WHEN vp.OwnerReputation < 0 THEN 'Novice'
            ELSE 'Intermediate'
        END AS OwnerExperienceLevel
    FROM 
        VisiblePosts vp
)
SELECT 
    fr.PostId,
    fr.Title,
    fr.CreationDate,
    fr.OwnerDisplayName,
    fr.PostStatus,
    fr.OwnerExperienceLevel
FROM 
    FinalResults fr
WHERE 
    fr.PostRank <= 50 
ORDER BY 
    fr.OwnerExperienceLevel, fr.PostRank;
