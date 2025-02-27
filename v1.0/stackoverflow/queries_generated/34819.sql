WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Body,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
        AND p.IsDeleted = 0  -- Assuming there is an IsDeleted column to filter out deleted posts
),
PostScores AS (
    SELECT 
        PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Votes v
    GROUP BY 
        PostId
),
TopTags AS (
    SELECT 
        t.TagName,
        COUNT(pt.PostId) AS TagCount
    FROM 
        Tags t
    LEFT JOIN 
        (SELECT UNNEST(STRING_TO_ARRAY(p.Tags, '><')) AS Tag, p.Id AS PostId 
         FROM Posts p) pt ON t.TagName = pt.Tag
    GROUP BY 
        t.TagName
    ORDER BY 
        TagCount DESC
    LIMIT 10
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS HistoryDate,
        ph.PostHistoryTypeId,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS hist_rn
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)  -- Close and Reopen events
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate AS PostCreationDate,
    rp.Body,
    rp.Score,
    ps.UpVotes,
    ps.DownVotes,
    ps.TotalVotes,
    rp.OwnerDisplayName,
    COUNT(DISTINCT pah.PostId) AS PostHistoryCount,
    STRING_AGG(DISTINCT tt.TagName, ', ') AS TopTags,
    MAX(phd.HistoryDate) AS LastHistoryDate
FROM 
    RecentPosts rp
LEFT JOIN 
    PostScores ps ON rp.PostId = ps.PostId
LEFT JOIN 
    PostHistoryDetails phd ON rp.PostId = phd.PostId 
LEFT JOIN 
    TopTags tt ON tt.TagName = ANY(STRING_TO_ARRAY(rp.Body, ' '))  -- Sample to demonstrate tag association
WHERE 
    rp.rn = 1  -- Get the most recent post for each user
GROUP BY 
    rp.PostId, 
    rp.Title, 
    rp.CreationDate, 
    rp.Body, 
    rp.Score, 
    ps.UpVotes, 
    ps.DownVotes, 
    ps.TotalVotes, 
    rp.OwnerDisplayName
ORDER BY 
    rp.CreationDate DESC;
