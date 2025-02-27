WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank,
        COUNT(DISTINCT c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        CASE 
            WHEN p.AcceptedAnswerId IS NOT NULL THEN 'Accepted Answer'
            ELSE 'No Accepted Answer'
        END AS AnswerStatus
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        pht.Name AS HistoryType,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '6 months'
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        rp.CreationDate,
        rp.ScoreRank,
        ph.Comment AS LatestComment,
        ph.HistoryType AS LatestHistoryType,
        ph.CreationDate AS LatestHistoryDate,
        CASE 
            WHEN ph.HistoryRank = 1 THEN ph.UserId 
            ELSE NULL 
        END AS LastEditorUserId
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistoryDetails ph ON rp.PostId = ph.PostId AND ph.HistoryRank = 1
    WHERE 
        rp.ScoreRank <= 10
),
FinalOutput AS (
    SELECT 
        fp.*,
        COALESCE(u.DisplayName, 'Unknown') AS LastEditorDisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBountyAmount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        FilteredPosts fp
    LEFT JOIN 
        Users u ON fp.LastEditorUserId = u.Id
    LEFT JOIN 
        Votes v ON fp.PostId = v.PostId 
    LEFT JOIN 
        Posts p ON fp.PostId = p.Id
    LEFT JOIN 
        LATERAL (SELECT unnest(string_to_array(p.Tags, '><')) AS TagName) AS t ON TRUE
    GROUP BY 
        fp.PostId, u.DisplayName
)
SELECT 
    *,
    CASE 
        WHEN TotalBountyAmount > 0 THEN 'Awarded Bounty'
        ELSE 'No Bounty Awarded'
    END AS BountyStatus,
    CASE 
        WHEN LatestComment IS NOT NULL THEN 'Commented'
        ELSE 'No Comments Yet'
    END AS CommentStatus
FROM 
    FinalOutput
WHERE 
    ViewCount > 1000 
ORDER BY 
    Score DESC, CreationDate DESC;
