WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.AnswerCount,
        p.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY EXTRACT(YEAR FROM p.CreationDate) ORDER BY p.ViewCount DESC) AS RankByViews
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.PostTypeId = 1  -- Only questions
),
FilteredTags AS (
    SELECT 
        PostId,
        unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS TagName
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Only questions
),
PopularTags AS (
    SELECT 
        TagName,
        COUNT(*) AS TagCount
    FROM 
        FilteredTags
    GROUP BY 
        TagName
    HAVING 
        COUNT(*) > 5  -- Only consider tags used more than 5 times
),
TopPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.OwnerDisplayName,
        RP.CreationDate,
        RP.ViewCount,
        PT.TagName
    FROM 
        RankedPosts RP
    JOIN 
        PopularTags PT ON RP.PostId IN (SELECT PostId FROM FilteredTags WHERE TagName = PT.TagName)
    WHERE 
        RP.RankByViews <= 10  -- Top 10 posts by views for each year
)
SELECT 
    TP.Title,
    TP.OwnerDisplayName,
    TP.CreationDate,
    TP.ViewCount,
    ARRAY_AGG(DISTINCT TP.TagName) AS AssociatedTags
FROM 
    TopPosts TP
GROUP BY 
    TP.PostId, TP.Title, TP.OwnerDisplayName, TP.CreationDate, TP.ViewCount
ORDER BY 
    CreationDate DESC;
