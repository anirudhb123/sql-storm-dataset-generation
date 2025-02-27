WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        SUM(v.BountyAmount) OVER (PARTITION BY p.Id) AS TotalBounty,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostLinks pl ON p.Id = pl.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Tags t ON t.Id = ANY(STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><')::int[])
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score
), 
PostHistoryInfo AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserId,
        ph.UserDisplayName,
        ph.Comment,
        CASE 
            WHEN ph.PostHistoryTypeId IN (10, 11) THEN
                CASE 
                    WHEN ph.Comment IS NULL THEN 'Unspecified Reason'
                    ELSE (SELECT Name FROM CloseReasonTypes WHERE Id = CAST(ph.Comment AS INT))
                END
            ELSE 'N/A'
        END AS CloseReason
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)
), 
HighScoredPosts AS (
    SELECT 
        rp.*,
        phi.CloseReason,
        COALESCE(CASE WHEN rp.ScoreRank <= 3 THEN 'Top Score' END, 'Other') AS ScoreCategory
    FROM 
        RankedPosts rp
    LEFT JOIN PostHistoryInfo phi ON rp.Id = phi.PostId
    WHERE 
        TotalBounty > 0 OR CloseReason IS NOT NULL
)

SELECT 
    hsp.Id,
    hsp.Title,
    hsp.CreationDate,
    hsp.Score,
    hsp.CommentCount,
    hsp.TotalBounty,
    hsp.Tags,
    hsp.CloseReason,
    hsp.ScoreCategory,
    CASE 
        WHEN hsp.CloseReason IS NOT NULL THEN 'Closed'
        ELSE 'Active'
    END AS PostStatus,
    (SELECT COUNT(*) FROM Posts p WHERE p.AcceptedAnswerId = hsp.Id) AS AcceptedAnswersCount,
    (SELECT SUM(BountyAmount) FROM Votes v WHERE v.PostId = hsp.Id AND v.VoteTypeId IN (8, 9)) AS TotalBountyReceived
FROM 
    HighScoredPosts hsp
ORDER BY 
    hsp.Score DESC, 
    hsp.CreationDate DESC
LIMIT 100;
