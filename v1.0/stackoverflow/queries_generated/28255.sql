WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        U.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT A.Id) AS AnswerCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        ARRAY_AGG(DISTINCT T.TagName) AS Tags,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Posts A ON p.Id = A.ParentId AND A.PostTypeId = 2
    LEFT JOIN 
        Comments C ON p.Id = C.PostId
    LEFT JOIN 
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS TagName ON TRUE
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, U.DisplayName
),
PopularUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(V.BountyAmount) AS TotalBounties,
        COUNT(DISTINCT V.PostId) AS TotalVotes
    FROM 
        Users U
    JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
    HAVING 
        SUM(V.BountyAmount) > 0 AND COUNT(DISTINCT V.PostId) > 5
),
PostHistoryAnalysis AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        PH.CreationDate,
        PH.UserDisplayName,
        PH.Comment,
        PH.Text
    FROM 
        Posts P
    JOIN 
        PostHistory PH ON P.Id = PH.PostId
    WHERE 
        PH.PostHistoryTypeId IN (10, 12) -- Interested in closed or deleted posts
        AND PH.CreationDate >= NOW() - INTERVAL '1 year'
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.Body,
    RP.CreationDate,
    RP.OwnerDisplayName,
    RP.AnswerCount,
    RP.CommentCount,
    RP.Tags,
    PU.DisplayName AS PopularUser,
    PU.TotalBounties,
    PH.CreationDate AS HistoryDate,
    PH.UserDisplayName AS Editor,
    PH.Comment AS EditorComment,
    PH.Text AS ChangeDetails
FROM 
    RankedPosts RP
LEFT JOIN 
    PopularUsers PU ON RP.OwnerUserId = PU.UserId
LEFT JOIN 
    PostHistoryAnalysis PH ON RP.PostId = PH.PostId
WHERE 
    RP.RecentPostRank = 1
ORDER BY 
    RP.CreationDate DESC, RP.AnswerCount DESC;
