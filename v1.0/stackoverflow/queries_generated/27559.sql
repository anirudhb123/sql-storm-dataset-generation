WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerDisplayName,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (ORDER BY p.Score DESC, p.ViewCount DESC) AS RankScore
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Tags t ON t.Id = ANY (string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')::int[])
    WHERE 
        p.PostTypeId = 1 -- Only Questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year' -- Questions from the last year
    GROUP BY 
        p.Id
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS HistoryDate,
        pht.Name AS ChangeType,
        ARRAY_AGG(DISTINCT ph.UserDisplayName) AS Editors
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId, HistoryDate, ChangeType
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(v.BountyAmount) AS TotalBounty,
        COUNT(DISTINCT v.PostId) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.Tags,
    rp.CommentCount,
    pHd.HistoryDate,
    pHd.ChangeType,
    pHd.Editors,
    ue.UserId,
    ue.DisplayName AS EngagedUser,
    ue.TotalBounty,
    ue.TotalVotes
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistoryDetails pHd ON rp.PostId = pHd.PostId
LEFT JOIN 
    UserEngagement ue ON ue.TotalVotes > 0 -- Include users who have voted
WHERE 
    rp.RankScore <= 10 -- Top 10 by score
ORDER BY 
    rp.RankScore;
