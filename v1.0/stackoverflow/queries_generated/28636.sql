WITH TagCounts AS (
    SELECT 
        UNNEST(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS TagName,
        ID AS PostId
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
),
AggregateTags AS (
    SELECT 
        TagName,
        COUNT(DISTINCT PostId) AS PostCount
    FROM 
        TagCounts
    GROUP BY 
        TagName
    HAVING 
        COUNT(DISTINCT PostId) > 5
),
TopUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS QuestionCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        P.PostTypeId = 1
    GROUP BY 
        U.Id
    ORDER BY 
        QuestionCount DESC
    LIMIT 10
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        PT.Name AS PostTypeName,
        ARRAY_AGG(DISTINCT AT.TagName) AS Tags
    FROM 
        Posts P
    JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    JOIN 
        TagCounts AT ON P.Id = AT.PostId
    WHERE 
        P.PostTypeId = 1
    GROUP BY 
        P.Id, PT.Name
)
SELECT 
    TU.UserId,
    TU.DisplayName,
    COALESCE(PD.Tags, '{}') AS Tags,
    PD.PostId,
    PD.Title,
    PD.CreationDate,
    PD.ViewCount,
    AG.PostCount
FROM 
    TopUsers TU
LEFT JOIN 
    PostDetails PD ON TU.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = PD.PostId)
LEFT JOIN 
    AggregateTags AG ON PD.Tags @> ARRAY[AG.TagName]
ORDER BY 
    TU.QuestionCount DESC, PD.ViewCount DESC;
