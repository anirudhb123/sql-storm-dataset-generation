WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON t.Id IN (SELECT UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '>'))::int)
    GROUP BY 
        p.Id
),
PopularUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    JOIN 
        Posts p ON p.OwnerUserId = u.Id
    WHERE 
        u.Reputation > 1000  -- Only considering users with reputation greater than 1000
    GROUP BY 
        u.Id
    HAVING 
        COUNT(p.Id) > 5  -- Considering users with more than 5 posts
),
HighlightedPosts AS (
    SELECT 
        r.PostId,
        r.Title,
        r.CreationDate,
        r.Tags,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        r.Score,
        r.ViewCount
    FROM 
        RankedPosts r
    JOIN 
        Users u ON r.OwnerUserId = u.Id
    WHERE 
        r.Rank <= 3  -- Top 3 posts for each user
),
FinalResults AS (
    SELECT 
        h.PostId,
        h.Title,
        h.CreationDate,
        h.Tags,
        h.OwnerDisplayName,
        h.OwnerReputation,
        h.Score,
        h.ViewCount,
        pu.UserId,
        pu.DisplayName AS PopularUserDisplayName,
        pu.TotalScore,
        pu.TotalViews
    FROM 
        HighlightedPosts h
    JOIN 
        PopularUsers pu ON h.OwnerUserId = pu.UserId
)
SELECT 
    PostId,
    Title,
    CreationDate,
    Tags,
    OwnerDisplayName,
    OwnerReputation,
    Score,
    ViewCount,
    PopularUserDisplayName,
    TotalScore,
    TotalViews
FROM 
    FinalResults
ORDER BY 
    OwnerReputation DESC, Score DESC;
