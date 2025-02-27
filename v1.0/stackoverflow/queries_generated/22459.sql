WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COALESCE(SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3) OVER (PARTITION BY p.Id), 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > (CURRENT_TIMESTAMP - INTERVAL '1 year')
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(b.Class = 1) AS GoldBadges,
        SUM(b.Class = 2) AS SilverBadges,
        SUM(b.Class = 3) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id
    HAVING 
        COUNT(DISTINCT p.Id) > 5
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.UserId AS EditorUserId,
        ph.CreationDate AS EditDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.Comment END) AS CloseReason,
        jsonb_agg(DISTINCT 
            CASE 
                WHEN ph.PostHistoryTypeId IN (1, 4, 6) THEN ph.Text 
                ELSE NULL 
            END) AS Edits
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate > (CURRENT_TIMESTAMP - INTERVAL '6 months')
    GROUP BY 
        ph.PostId, ph.UserId
),
FinalResults AS (
    SELECT 
        pu.UserId,
        pu.DisplayName,
        SUM(rp.Score) AS TotalScore,
        SUM(rp.UpVotes) - SUM(rp.DownVotes) AS NetVotes,
        COUNT(DISTINCT rp.PostId) AS PostsEditedCount,
        COALESCE(SUM(CASE WHEN phd.CloseReason IS NOT NULL THEN 1 ELSE 0 END), 0) AS PostsClosedCount,
        COALESCE(SUM(CASE WHEN phd.Edits IS NOT NULL THEN 1 ELSE 0 END), 0) AS TotalEdits
    FROM 
        TopUsers pu
    LEFT JOIN 
        RankedPosts rp ON pu.UserId = rp.OwnerUserId
    LEFT JOIN 
        PostHistoryDetails phd ON rp.PostId = phd.PostId
    GROUP BY 
        pu.UserId, pu.DisplayName
)
SELECT 
    UserId,
    DisplayName,
    TotalScore,
    NetVotes,
    PostsEditedCount,
    PostsClosedCount,
    TotalEdits
FROM 
    FinalResults
ORDER BY 
    TotalScore DESC, NetVotes DESC, PostsEditedCount DESC
LIMIT 10;
