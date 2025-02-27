
WITH TagCounts AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    JOIN 
        (SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION 
         SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1  
    GROUP BY 
        TagName
),
FrequentTags AS (
    SELECT 
        TagName,
        PostCount,
        @rownum := @rownum + 1 AS TagRank
    FROM 
        TagCounts, (SELECT @rownum := 0) r
    WHERE 
        PostCount > 5  
),
UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounties
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalBounties,
        @userrownum := @userrownum + 1 AS UserRank
    FROM 
        UserReputation, (SELECT @userrownum := 0) r
    ORDER BY 
        TotalBounties DESC, Reputation DESC
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        CA.TagName,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    JOIN 
        FrequentTags CA ON CA.TagName = SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, '><', numbers.n), '><', -1)
    JOIN 
        (SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION 
         SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers ON CHAR_LENGTH(P.Tags) - CHAR_LENGTH(REPLACE(P.Tags, '><', '')) >= numbers.n - 1
    WHERE 
        P.PostTypeId = 1  
),
Analytics AS (
    SELECT 
        PD.PostId,
        PD.Title,
        PD.TagName,
        PD.CreationDate,
        PD.Score,
        PD.ViewCount,
        PD.OwnerDisplayName,
        TU.DisplayName AS TopUserDisplayName
    FROM 
        PostDetails PD
    LEFT JOIN 
        TopUsers TU ON PD.OwnerDisplayName = TU.DisplayName  
)
SELECT 
    A.PostId,
    A.Title AS QuestionTitle,
    A.TagName,
    A.CreationDate,
    A.Score,
    A.ViewCount,
    A.OwnerDisplayName,
    COALESCE(A.TopUserDisplayName, 'Non-top User') AS TopUserIndicator
FROM 
    Analytics A
ORDER BY 
    A.ViewCount DESC, A.Score DESC
LIMIT 10;
