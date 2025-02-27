
WITH TagCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT S.Tag) AS TagCount,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users U
    JOIN 
        Posts p ON U.Id = p.OwnerUserId
    LEFT JOIN 
        (SELECT 
            SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS Tag
        FROM 
            (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
             UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
        WHERE 
            CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1) AS S ON TRUE
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        U.Id, U.DisplayName
), 
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        TagCount,
        TotalViews,
        RANK() OVER (ORDER BY TotalViews DESC) AS ViewRank
    FROM 
        TagCounts
    WHERE 
        TagCount > 0
),

MostActiveTags AS (
    SELECT 
        T.TagName, 
        COUNT(P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        T.TagName
    ORDER BY 
        TotalViews DESC
    LIMIT 10
)

SELECT 
    U.DisplayName AS TopUser,
    U.TagCount,
    U.TotalViews,
    T.TagName AS MostActiveTag,
    T.PostCount,
    T.TotalViews AS TagTotalViews
FROM 
    TopUsers U
JOIN 
    MostActiveTags T ON TRUE
WHERE 
    U.ViewRank <= 5 
ORDER BY 
    U.TotalViews DESC, 
    T.TotalViews DESC;
