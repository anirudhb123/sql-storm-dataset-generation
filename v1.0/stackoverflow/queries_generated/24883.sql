WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(v.VoteTypeId = 2, 0)) AS UpVotes,
        SUM(COALESCE(v.VoteTypeId = 3, 0)) AS DownVotes,
        AVG(u.Reputation) AS AvgReputation
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
RecentEdits AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS EditRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Body, or Tags
),
FinalResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rs.PostCount,
        rs.UpVotes,
        rs.DownVotes,
        ue.CreationDate AS LastEditDate,
        ue.Comment AS LastEditComment,
        COALESCE(NULLIF(rp.Score, 0), 1) AS EffectiveScore -- Avoid division by zero for effective score.
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserStats rs ON rp.OwnerDisplayName = rs.UserId  -- Linking with UserStats by matching DisplayNames to UserIds.
    LEFT JOIN 
        RecentEdits ue ON rp.PostId = ue.PostId AND ue.EditRank = 1
)
SELECT 
    fr.PostId,
    fr.Title,
    fr.OwnerDisplayName,
    fr.PostCount,
    fr.UpVotes,
    fr.DownVotes,
    fr.LastEditDate,
    fr.LastEditComment,
    fr.EffectiveScore,
    CASE 
        WHEN fr.UpVotes > fr.DownVotes THEN 'More UpVotes'
        WHEN fr.DownVotes > fr.UpVotes THEN 'More DownVotes'
        ELSE 'Equal Votes' 
    END AS VoteStatus,
    CASE 
        WHEN fr.LastEditDate IS NOT NULL THEN 'Edited Recently'
        ELSE 'Not Edited Recently' 
    END AS EditStatus
FROM 
    FinalResults fr
WHERE 
    fr.PostCount > 10
ORDER BY 
    fr.EffectiveScore DESC, 
    fr.PostCount DESC
LIMIT 100;
