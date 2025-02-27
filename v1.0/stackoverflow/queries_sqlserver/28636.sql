
WITH TagCounts AS (
    SELECT 
        VALUE AS TagName,
        ID AS PostId
    FROM 
        Posts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><')
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
        SUM(ISNULL(P.ViewCount, 0)) AS TotalViews
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        P.PostTypeId = 1
    GROUP BY 
        U.Id, U.DisplayName
    ORDER BY 
        QuestionCount DESC
    OFFSET 0 ROWS 
    FETCH NEXT 10 ROWS ONLY
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        PT.Name AS PostTypeName,
        STRING_AGG(DISTINCT AT.TagName, ', ') AS Tags
    FROM 
        Posts P
    JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    JOIN 
        TagCounts AT ON P.Id = AT.PostId
    WHERE 
        P.PostTypeId = 1
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.ViewCount, PT.Name
)
SELECT 
    TU.UserId,
    TU.DisplayName,
    ISNULL(PD.Tags, '') AS Tags,
    PD.PostId,
    PD.Title,
    PD.CreationDate,
    PD.ViewCount,
    AG.PostCount
FROM 
    TopUsers TU
LEFT JOIN 
    PostDetails PD ON TU.UserId = (SELECT TOP 1 OwnerUserId FROM Posts WHERE Id = PD.PostId)
LEFT JOIN 
    AggregateTags AG ON PD.Tags LIKE '%' + AG.TagName + '%'
ORDER BY 
    TU.QuestionCount DESC, PD.ViewCount DESC;
