WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS RankInType,
        SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id) AS UpVotes,
        SUM(v.VoteTypeId = 3) OVER (PARTITION BY p.Id) AS DownVotes
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),

HighScoringPosts AS (
    SELECT 
        PostId, Title, Score, ViewCount, RankInType,
        UpVotes, DownVotes,
        CASE 
            WHEN DownVotes = 0 THEN UpVotes 
            ELSE UpVotes * 1.0 / DownVotes 
        END AS VoteRatio
    FROM 
        RankedPosts
    WHERE 
        RankInType <= 5
),

TagDetails AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(p.Id) AS PostCount,
        ARRAY_AGG(DISTINCT p.Id) AS PostIds,
        MAX(CASE WHEN ph.PostId IS NOT NULL THEN 'HasPostHistory' ELSE 'NoPostHistory' END) AS PostHistoryFlag
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags ILIKE '%' || t.TagName || '%'
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        t.Id, t.TagName
)

SELECT 
    tp.TagId,
    tp.TagName,
    tp.PostCount,
    tp.PostIds,
    hsp.Title,
    hsp.Score,
    hsp.VoteRatio,
    hsp.UpVotes,
    hsp.DownVotes,
    CASE 
        WHEN tp.PostHistoryFlag = 'HasPostHistory' THEN 'This tag is well-documented'
        ELSE 'This tag lacks documentation' 
    END AS DocumentationStatus
FROM 
    TagDetails tp
JOIN 
    HighScoringPosts hsp ON POSITION(hsp.PostId::text IN tp.PostIds::text) > 0
WHERE 
    hsp.VoteRatio IS NOT NULL
ORDER BY 
    tp.PostCount DESC, hsp.Score DESC;

-- Aggregate close reasons from PostHistory where applicable
WITH CloseReasonSummary AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseVotes,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (11, 13) THEN 1 END) AS ReopenUndeleteVotes
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    Posts.Title,
    CloseReasonSummary.CloseVotes,
    CloseReasonSummary.ReopenUndeleteVotes,
    CASE 
        WHEN CloseReasonSummary.CloseVotes > 0 THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus
FROM 
    CloseReasonSummary
JOIN 
    Posts ON CloseReasonSummary.PostId = Posts.Id
WHERE 
    Posts.CreationDate >= NOW() - INTERVAL '6 months'
ORDER BY 
    CloseVotes DESC, ReopenUndeleteVotes DESC;

