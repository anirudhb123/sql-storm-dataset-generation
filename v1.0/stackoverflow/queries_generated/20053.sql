WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.PostTypeId
),
BestAnswer AS (
    SELECT 
        p.Id AS PostId,
        p.AcceptedAnswerId,
        a.Title AS AcceptedAnswerTitle,
        a.Score AS AcceptedAnswerScore
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.AcceptedAnswerId = a.Id
    WHERE 
        p.PostTypeId = 1 -- Questions
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COUNT(DISTINCT v.Id) AS TotalVotes
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
        MAX(ph.CreationDate) AS LastEditDate,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    CASE 
        WHEN be.AcceptedAnswerId IS NOT NULL THEN 'Yes'
        ELSE 'No'
    END AS HasAcceptedAnswer,
    be.AcceptedAnswerTitle,
    be.AcceptedAnswerScore,
    ue.DisplayName AS UserDisplayName,
    ue.TotalBounty,
    ue.TotalVotes,
    COALESCE(phs.LastEditDate, 'No Edits') AS LastEditDate,
    phs.HistoryTypes
FROM 
    RankedPosts rp
LEFT JOIN 
    BestAnswer be ON rp.PostId = be.PostId
LEFT JOIN 
    UserEngagement ue ON rp.PostId = ue.UserId
LEFT JOIN 
    PostHistorySummary phs ON rp.PostId = phs.PostId
WHERE 
    rp.Rank <= 10 
    AND (rp.ViewCount > 100 OR rp.CommentCount > 5)
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;

-- Incorporating some NULL logic
-- If there are no bounty votes, show as 'No Bounties' if TotalBounty is zero.
UPDATE UserEngagement
SET TotalBounty = CASE 
                    WHEN TotalBounty = 0 THEN 'No Bounties' 
                    ELSE TotalBounty 
                  END;

-- Implementing a bizarre case with string functions for tag processing
SELECT 
    rp.PostId,
    rp.Title,
    CASE 
        WHEN LENGTH(rp.Title) - LENGTH(REPLACE(rp.Title, ' ', '')) > 10 THEN 'Verbose Title'
        ELSE NULL 
    END AS TitleDescription,
    SPLIT_PART(JSON_AGG(DISTINCT tags.TagName)::TEXT, ',', 1) AS FirstTag
FROM 
    RankedPosts rp
LEFT JOIN 
    UNNEST(string_to_array(rp.Tags, '><')) as tags(TagName)
GROUP BY 
    rp.PostId, rp.Title;
