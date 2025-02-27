WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.UserId AS OwnerUserId,
        p.Title,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS TagRank,
        COUNT(v.Id) FILTER (WHERE vt.Name = 'UpMod') AS UpVotesCount,
        COUNT(v.Id) FILTER (WHERE vt.Name = 'DownMod') AS DownVotesCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        p.Id, p.UserId, p.Title, p.CreationDate
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS TotalBadges,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostHistoryAggregated AS (
    SELECT
        ph.PostId,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes,
        COUNT(*) FILTER (WHERE ph.PostHistoryTypeId IN (10, 11)) AS CloseOpenChanges
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        us.DisplayName AS UserDisplayName,
        us.Reputation,
        pha.HistoryTypes,
        pha.CloseOpenChanges,
        rp.UpVotesCount,
        rp.DownVotesCount,
        CASE 
            WHEN rp.TagRank <= 3 THEN 'Top Tag'
            ELSE 'Other'
        END AS Category
    FROM 
        RankedPosts rp
    JOIN 
        UserStats us ON rp.OwnerUserId = us.UserId
    JOIN 
        PostHistoryAggregated pha ON rp.PostId = pha.PostId
    WHERE 
        rp.UpVotesCount > rp.DownVotesCount
        AND us.Reputation > 1000
)
SELECT 
    PostId,
    Title,
    UserDisplayName,
    Reputation,
    CreationDate,
    HistoryTypes,
    CloseOpenChanges,
    UpVotesCount,
    DownVotesCount,
    Category,
    CASE 
        WHEN CloseOpenChanges = 0 THEN 'No changes' 
        WHEN CloseOpenChanges <= 2 THEN 'Few changes' 
        ELSE 'Many changes'
    END AS ChangeFrequency
FROM 
    FilteredPosts
ORDER BY 
    UpVotesCount DESC, CreationDate DESC;
