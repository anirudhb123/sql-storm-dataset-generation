WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.ViewCount, 
        p.Score, 
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= current_date - interval '1 year'
),
AggregatedVotes AS (
    SELECT
        v.PostId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    WHERE 
        v.CreationDate >= current_date - interval '1 year'
    GROUP BY 
        v.PostId
),
RelevantPostHistory AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) as EditCount,
        MAX(ph.CreationDate) AS LastEdited
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Edit Body, Edit Tags
    GROUP BY 
        ph.PostId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(b.Class), 0) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    av.UpVotes,
    av.DownVotes,
    av.TotalVotes,
    rph.EditCount,
    rph.LastEdited,
    ur.UserId,
    ur.DisplayName,
    ur.Reputation,
    CASE 
        WHEN ur.Reputation > 1000 THEN 'Experienced'
        WHEN ur.Reputation IS NULL THEN 'Unknown'
        ELSE 'Novice'
    END AS UserType,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    RankedPosts rp
LEFT JOIN 
    AggregatedVotes av ON rp.PostId = av.PostId
LEFT JOIN 
    RelevantPostHistory rph ON rp.PostId = rph.PostId
LEFT JOIN 
    Posts p ON p.Id = rp.PostId
JOIN 
    Tags t ON t.Id = ANY(STRING_TO_ARRAY(p.Tags, ',')::int[]) -- Assumes tags are stored as comma-separated IDs
JOIN 
    Users ur ON p.OwnerUserId = ur.Id
WHERE 
    rp.Rank <= 5 -- Top 5 in each post type
GROUP BY 
    rp.PostId, rp.Title, rp.CreationDate, av.UpVotes, av.DownVotes, av.TotalVotes, rph.EditCount, rph.LastEdited, ur.UserId, ur.DisplayName, ur.Reputation
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
