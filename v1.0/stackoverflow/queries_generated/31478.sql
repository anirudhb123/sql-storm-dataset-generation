WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATEADD(month, -6, GETDATE()) -- Posts created in the last 6 months
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS HistoryDate,
        ph.UserDisplayName,
        ph.PostHistoryTypeId,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12)  -- Closed, Reopened, Deleted
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
FilteredPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.Score,
        RP.CreationDate,
        RP.CommentCount,
        RP.DownVoteCount,
        PH.HistoryDate,
        PH.UserDisplayName AS Editor,
        UB.BadgeCount,
        UB.GoldBadges,
        UB.SilverBadges,
        UB.BronzeBadges
    FROM 
        RankedPosts RP
    LEFT JOIN 
        PostHistoryDetails PH ON RP.PostId = PH.PostId AND PH.HistoryRank = 1
    LEFT JOIN 
        UserBadges UB ON RP.PostId = UB.UserId
)
SELECT 
    FP.PostId,
    FP.Title,
    FP.Score,
    FP.CreationDate,
    FP.CommentCount,
    FP.DownVoteCount,
    COALESCE(FP.Editor, 'No editor') AS LastEditedBy,
    COALESCE(FP.HistoryDate, 'N/A') AS LastActionDate,
    COALESCE(FP.BadgeCount, 0) AS TotalBadges,
    COALESCE(FP.GoldBadges, 0) AS GoldBadges,
    COALESCE(FP.SilverBadges, 0) AS SilverBadges,
    COALESCE(FP.BronzeBadges, 0) AS BronzeBadges
FROM 
    FilteredPosts FP
WHERE 
    FP.CommentCount > 5
ORDER BY 
    FP.Score DESC, 
    FP.CreationDate DESC;
