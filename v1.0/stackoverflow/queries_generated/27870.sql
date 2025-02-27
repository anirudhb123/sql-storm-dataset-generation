WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only considering questions
),
TopTaggedPosts AS (
    SELECT 
        rp.Tag AS Tag,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.OwnerDisplayName
    FROM (
        SELECT 
            rp.Id,
            unnest(string_to_array(substring(rp.Tags, 2, length(rp.Tags)-2), '><')) AS Tag,
            rp.Title,
            rp.CreationDate,
            rp.ViewCount,
            rp.Score,
            rp.OwnerDisplayName
        FROM 
            RankedPosts rp
    ) rp
    WHERE 
        rp.Rank <= 5 -- Get top 5 ranked questions for each tag
),
TagStats AS (
    SELECT 
        Tag,
        COUNT(*) AS PostCount,
        AVG(ViewCount) AS AverageViewCount,
        SUM(Score) AS TotalScore
    FROM 
        TopTaggedPosts
    GROUP BY 
        Tag
),
FinalStats AS (
    SELECT 
        ts.Tag,
        ts.PostCount,
        ts.AverageViewCount,
        ts.TotalScore,
        CASE 
            WHEN ts.PostCount > 10 THEN 'High Activity'
            WHEN ts.PostCount BETWEEN 5 AND 10 THEN 'Medium Activity'
            ELSE 'Low Activity'
        END AS ActivityLevel
    FROM 
        TagStats ts
)
SELECT 
    fs.Tag,
    fs.PostCount,
    fs.AverageViewCount,
    fs.TotalScore,
    fs.ActivityLevel
FROM 
    FinalStats fs
ORDER BY 
    fs.TotalScore DESC, fs.PostCount DESC;
