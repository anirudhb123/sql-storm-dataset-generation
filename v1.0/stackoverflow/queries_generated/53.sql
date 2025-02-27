WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
),
TagStats AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%')
    GROUP BY 
        t.TagName
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,
        COALESCE(SUM(v.VoteTypeId = 5), 0) AS Favorites
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS ChangeCount
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    ts.TagName,
    ts.PostCount,
    ts.TotalViews,
    ue.UserId,
    ue.DisplayName,
    ue.UpVotes,
    ue.DownVotes,
    ue.Favorites,
    phs.ChangeCount
FROM 
    RankedPosts rp
LEFT JOIN 
    TagStats ts ON rp.PostId = ts.PostCount
LEFT JOIN 
    UserEngagement ue ON rp.PostId = ue.UserId
LEFT JOIN 
    PostHistorySummary phs ON rp.PostId = phs.PostId
WHERE 
    (rp.PostRank <= 5 OR ts.PostCount IS NOT NULL)
    AND (ue.UpVotes > 10 OR ue.DownVotes < 5)
ORDER BY 
    rp.CreationDate DESC, rp.Score DESC;
