WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        ARRAY_AGG(t.TagName) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        UNNEST(string_to_array(p.Tags, '><')) AS t(TagName) ON true
    GROUP BY 
        p.Id, u.DisplayName
),
RecentVotes AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
ClosedPostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS ClosedDate,
        ph.Comment
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
),
HighlyRankedPosts AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.ViewCount,
        rp.Tags,
        COALESCE(rv.UpVotes, 0) AS UpVotes,
        COALESCE(rv.DownVotes, 0) AS DownVotes,
        rh.ClosedDate,
        CASE 
            WHEN rh.ClosedDate IS NOT NULL THEN 'Closed'
            ELSE 'Open'
        END AS PostStatus
    FROM 
        RankedPosts rp
    LEFT JOIN 
        RecentVotes rv ON rp.PostId = rv.PostId
    LEFT JOIN 
        ClosedPostHistory rh ON rp.PostId = rh.PostId
    WHERE 
        rp.Rank <= 5
)
SELECT 
    h.PostId,
    h.Title,
    h.OwnerDisplayName,
    h.ViewCount,
    h.UpVotes,
    h.DownVotes,
    h.Tags,
    h.PostStatus,
    COALESCE(h.ClosedDate, 'No Closure') AS ClosureInfo
FROM 
    HighlyRankedPosts h
WHERE 
    h.UpVotes - h.DownVotes > 0
ORDER BY 
    h.ViewCount DESC;
