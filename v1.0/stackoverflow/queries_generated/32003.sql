WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE()) 
        AND p.Score > 0
),
PopularTags AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(pt.PostId) AS PostCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')::int[]) 
    GROUP BY 
        t.Id, t.TagName
    HAVING 
        COUNT(pt.PostId) > 10 
),
UserScores AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN v.VoteTypeId IN (1, 5) THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (1, 4) THEN 1 END) AS TitleEditCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
FinalResults AS (
    SELECT 
        rp.Title,
        rp.Score,
        ut.DisplayName,
        pt.TagName,
        phs.CloseCount,
        phs.ReopenCount,
        phs.TitleEditCount,
        rp.CreationDate,
        RANK() OVER (PARTITION BY pt.TagName ORDER BY rp.Score DESC) AS TagRank
    FROM 
        RankedPosts rp
    JOIN 
        Users ut ON rp.OwnerUserId = ut.Id
    JOIN 
        PostHistorySummary phs ON rp.PostId = phs.PostId
    JOIN 
        PopularTags pt ON rp.PostId = ANY(string_to_array(substring(pt.TagName, 2, length(pt.TagName) - 2), '><')::int[])
    WHERE 
        rp.RankScore <= 5
)

SELECT 
    Title,
    Score,
    DisplayName,
    TagName,
    CloseCount,
    ReopenCount,
    TitleEditCount,
    CreationDate
FROM 
    FinalResults
WHERE 
    TagRank <= 3
ORDER BY 
    Score DESC, CreationDate DESC;
